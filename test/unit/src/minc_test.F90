module minc_test

  ! Tests for minc module

#include <petsc/finclude/petscsys.h>
#include <petsc/finclude/petscdm.h>

  use petscsys
  use petscdm
  use zofu
  use kinds_module
  use minc_module

  implicit none
  private 

  public :: setup, teardown, setup_test
  public :: test_proximity, test_proximity_derivative, &
       test_inner_connection_distance, test_geometry

contains

!------------------------------------------------------------------------

  subroutine setup()

    use profiling_module, only: init_profiling

    ! Locals:
    PetscErrorCode :: ierr

    call PetscInitialize(PETSC_NULL_CHARACTER, ierr); CHKERRQ(ierr)
    call init_profiling()

  end subroutine setup

!------------------------------------------------------------------------

  subroutine teardown()

    PetscErrorCode :: ierr

    call PetscFinalize(ierr); CHKERRQ(ierr)

  end subroutine teardown

!------------------------------------------------------------------------

  subroutine setup_test(test)

    class(unit_test_type), intent(in out) :: test

    test%tolerance = 1.e-7

  end subroutine setup_test

!------------------------------------------------------------------------

  subroutine test_proximity(test)
    ! MINC proximity functions

    use fson
    use fson_mpi_module
    use dictionary_module

    class(unit_test_type), intent(in out) :: test
    ! Locals:
    type(minc_type) :: minc
    DM :: dm
    PetscInt :: ir
    type(fson_value), pointer :: json
    PetscMPIInt :: rank
    PetscErrorCode :: ierr, err
    type(dictionary_type) :: rock_types

    call MPI_COMM_RANK(PETSC_COMM_WORLD, rank, ierr)
    ir = 1

    json => fson_parse_mpi(str = '{"geometry": {"fracture": {"planes": 1, "spacing": 50.}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(1, minc%num_fracture_planes, '1 set of fracture planes')
       call test%assert(0._dp, minc%proximity(0._dp), '1 plane x = 0')
       call test%assert(0.4_dp, minc%proximity(10._dp), '1 plane x = 10')
       call test%assert(0.8_dp, minc%proximity(20._dp), '1 plane x = 20')
       call test%assert(1._dp, minc%proximity(25._dp), '1 plane x = 25')
       call test%assert(1._dp, minc%proximity(30._dp), '1 plane x = 30')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

    json => fson_parse_mpi(str = '{"geometry": {"fracture": {"planes": 2, "spacing": [50, 80]}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(2, minc%num_fracture_planes, '2 sets of fracture planes')
       call test%assert(0._dp, minc%proximity(0._dp), '2 planes x = 0')
       call test%assert(0.55_dp, minc%proximity(10._dp), '2 planes x = 10')
       call test%assert(0.9_dp, minc%proximity(20._dp), '2 planes x = 20')
       call test%assert(1._dp, minc%proximity(25._dp), '2 planes x = 25')
       call test%assert(1._dp, minc%proximity(30._dp), '2 planes x = 30')
       call test%assert(1._dp, minc%proximity(45._dp), '2 planes x = 45')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

    json => fson_parse_mpi(str = '{"geometry": {"fracture": {"planes": 3, "spacing": [50, 80, 60]}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(3, minc%num_fracture_planes, '3 sets of fracture planes')
       call test%assert(0._dp, minc%proximity(0._dp), '3 planes x = 0')
       call test%assert(0.7_dp, minc%proximity(10._dp), '3 planes x = 10')
       call test%assert(29._dp / 30._dp, minc%proximity(20._dp), '3 planes x = 20')
       call test%assert(1._dp, minc%proximity(25._dp), '3 planes x = 25')
       call test%assert(1._dp, minc%proximity(30._dp), '3 planes x = 30')
       call test%assert(1._dp, minc%proximity(45._dp), '3 planes x = 45')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

  end subroutine test_proximity

!------------------------------------------------------------------------

  subroutine test_proximity_derivative(test)
    ! MINC proximity function derivatives

    use fson
    use fson_mpi_module
    use dictionary_module

    class(unit_test_type), intent(in out) :: test
    ! Locals:
    type(minc_type) :: minc
    DM :: dm
    PetscInt :: ir
    type(fson_value), pointer :: json
    type(dictionary_type) :: rock_types
    PetscMPIInt :: rank
    PetscErrorCode :: ierr, err

    call MPI_COMM_RANK(PETSC_COMM_WORLD, rank, ierr)
    ir = 1

    json => fson_parse_mpi(str = '{"geometry": {"fracture": {"planes": 1, "spacing": 50.}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(0.04_dp, &
            minc%proximity_derivative(0._dp), '1 plane x = 0')
       call test%assert(0.04_dp, &
            minc%proximity_derivative(10._dp), '1 plane x = 10')
       call test%assert(0.04_dp, &
            minc%proximity_derivative(20._dp), '1 plane x = 20')
       call test%assert(0.04_dp, &
            minc%proximity_derivative(25._dp), '1 plane x = 25')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

    json => fson_parse_mpi(str = '{"geometry": {"fracture": {"planes": 2, "spacing": [50, 80]}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(0.065_dp, &
            minc%proximity_derivative(0._dp), '2 planes x = 0')
       call test%assert(0.045_dp, &
            minc%proximity_derivative(10._dp), '2 planes x = 10')
       call test%assert(0.025_dp, &
            minc%proximity_derivative(20._dp), '2 planes x = 20')
       call test%assert(0.015_dp, &
            minc%proximity_derivative(25._dp), '2 planes x = 25')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

    json => fson_parse_mpi(str = '{"geometry": {"fracture": {"planes": 2, "spacing": 50}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert([50._dp, 50._dp], minc%fracture_spacing, &
            '2 planes equal spacing fracture spacing')
       call test%assert(0.08_dp, &
            minc%proximity_derivative(0._dp), '2 planes equal spacing x = 0')
       call test%assert(0.048_dp, &
            minc%proximity_derivative(10._dp), '2 planes equal spacing x = 10')
       call test%assert(0.016_dp, &
            minc%proximity_derivative(20._dp), '2 planes equal spacing x = 20')
       call test%assert(0._dp, &
            minc%proximity_derivative(25._dp), '2 planes equal spacing x = 25')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

    json => fson_parse_mpi(str = '{"geometry": {"fracture": {"planes": 3, "spacing": [50, 80, 60]}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(0.0983333333_dp, &
            minc%proximity_derivative(0._dp), '3 planes x = 0')
       call test%assert(0.045_dp, &
            minc%proximity_derivative(10._dp), '3 planes x = 10')
       call test%assert(0.0116666667_dp, &
            minc%proximity_derivative(20._dp), '3 planes x = 20')
       call test%assert(2.5e-3_dp, &
            minc%proximity_derivative(25._dp), '3 planes x = 25')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

  end subroutine test_proximity_derivative

!------------------------------------------------------------------------

  subroutine test_inner_connection_distance(test)
    ! MINC inner connection distance

    use fson
    use fson_mpi_module
    use dictionary_module

    class(unit_test_type), intent(in out) :: test
    ! Locals:
    type(minc_type) :: minc
    DM :: dm
    PetscInt :: ir
    type(fson_value), pointer :: json
    type(dictionary_type) :: rock_types
    PetscMPIInt :: rank
    PetscErrorCode :: ierr, err

    call MPI_COMM_RANK(PETSC_COMM_WORLD, rank, ierr)
    ir = 1

    json => fson_parse_mpi(str = '{"geometry": {"fracture": {"planes": 1, "spacing": 50.}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(25._dp / 3._dp, &
            minc%inner_connection_distance(0._dp), '1 plane x = 0')
       call test%assert(5._dp, &
            minc%inner_connection_distance(10._dp), '1 plane x = 10')
       call test%assert(5._dp / 3._dp, &
            minc%inner_connection_distance(20._dp), '1 plane x = 20')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

    json => fson_parse_mpi(str = '{"geometry": {"fracture": {"planes": 2, "spacing": [50, 80]}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(100._dp / 13._dp, &
            minc%inner_connection_distance(0._dp), '2 planes x = 0')
       call test%assert(5._dp, &
            minc%inner_connection_distance(10._dp), '2 planes x = 10')
       call test%assert(2._dp, &
            minc%inner_connection_distance(20._dp), '2 planes x = 20')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

    json => fson_parse_mpi(str = '{"geometry": {"fracture": {"planes": 3, "spacing": [50, 80, 60]}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(360._dp / 59._dp, &
            minc%inner_connection_distance(0._dp), '3 planes x = 0')
       call test%assert(4._dp, &
            minc%inner_connection_distance(10._dp), '3 planes x = 10')
       call test%assert(12._dp / 7._dp, &
            minc%inner_connection_distance(20._dp), '3 planes x = 20')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

  end subroutine test_inner_connection_distance

!------------------------------------------------------------------------

  subroutine test_geometry(test)
    ! MINC geometry

    use fson
    use fson_mpi_module
    use dictionary_module

    class(unit_test_type), intent(in out) :: test
    ! Locals:
    type(minc_type) :: minc
    DM :: dm
    PetscInt :: ir
    type(fson_value), pointer :: json
    type(dictionary_type) :: rock_types
    PetscMPIInt :: rank
    PetscErrorCode :: ierr, err

    call MPI_COMM_RANK(PETSC_COMM_WORLD, rank, ierr)

    json => fson_parse_mpi(str = '{"geometry": {' // &
         '"fracture": {"volume": 0.1, "planes": 1, "spacing": 50.}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(0, err, '1 plane 1 level error')
       call test%assert([0.1_dp, 0.9_dp], minc%volume, &
            '1 plane 1 level volume fractions')
       call test%assert([0.036_dp], &
            minc%connection_area, '1 plane 1 level connection areas')
       call test%assert([0._dp, 25._dp / 3._dp], &
            minc%connection_distance, '1 plane 1 level connection distances')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

    json => fson_parse_mpi(str = '{"geometry": {' // &
         '"fracture": {"volume": 0.1, "planes": 1, "spacing": 100.}, ' // &
         '"matrix": {"volume": [0.3, 0.6]}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(0, err, '1 plane 2 levels error')
       call test%assert([0.1_dp, 0.3_dp, 0.6_dp], minc%volume, &
            '1 plane 2 levels volume fractions')
       call test%assert([0.018_dp, 0.018_dp], &
            minc%connection_area, '1 plane 2 levels connection areas')
       call test%assert([0._dp, 25._dp / 3._dp, 100._dp / 9._dp], &
            minc%connection_distance, '1 plane 2 levels connection distances')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

    json => fson_parse_mpi(str = '{"geometry": {' // &
         '"fracture": {"volume": 10, "planes": 1, "spacing": 100.}, ' // &
         '"matrix": {"volume": [20, 30, 40]}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(0, err, '1 plane 3 levels error')
       call test%assert([0.1_dp, 0.2_dp, 0.3_dp, 0.4_dp], minc%volume, &
            '1 plane 3 levels volume fractions')
       call test%assert([0.018_dp, 0.018_dp, 0.018_dp], &
            minc%connection_area, '1 plane 3 levels connection areas')
       call test%assert([0._dp, 50._dp / 9._dp, 25._dp / 3._dp, 7400._dp / 999._dp], &
            minc%connection_distance, '1 plane 3 levels connection distances')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

    json => fson_parse_mpi(str = '{"geometry": {' // &
         '"fracture": {"volume": 5, "planes": 2, "spacing": 100}, ' // &
         '"matrix": {"volume": [20, 30, 45]}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(0, err, '2 planes 3 levels error')
       call test%assert([0.05_dp, 0.2_dp, 0.3_dp, 0.45_dp], minc%volume, &
            '2 planes 3 levels volume fractions')
       call test%assert([0.038_dp, 0.033763886490617179_dp, &
            0.026153393818234151_dp], &
            minc%connection_area, '2 planes 3 levels connection areas')
       call test%assert([0._dp, 2.78691708403391_dp, &
            5.006902875674109_dp, 8.6030900201459914_dp], &
            minc%connection_distance, '2 planes 3 levels connection distances')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

    json => fson_parse_mpi(str = '{"geometry": {' // &
         '"fracture": {"volume": 5, "planes": 2, "spacing": [100, 80]}, ' // &
         '"matrix": {"volume": [20, 30, 45]}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(0, err, '2 planes 3 levels variable spacing error')
       call test%assert([0.05_dp, 0.2_dp, 0.3_dp, 0.45_dp], minc%volume, &
            '2 planes 3 levels variable spacing volume fractions')
       call test%assert([0.04275_dp, 0.038046846447656414_dp, &
            0.029623680667175543_dp], minc%connection_area, &
            '2 planes 3 levels variable spacing connection areas')
       call test%assert([0._dp, 2.4753441451477878_dp, &
            4.433244588928682_dp, 7.595274770950577_dp], &
            minc%connection_distance, &
            '2 planes 3 levels variable spacing connection distances')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

    json => fson_parse_mpi(str = '{"geometry": {' // &
         '"fracture": {"volume": 10, "planes": 3, "spacing": [100, 80, 90]}, ' // &
         '"matrix": {"volume": [30, 60]}}}')
    call minc%init(json, dm, 0, "minc", rock_types, ir, err = err)
    if (rank == 0) then
       call test%assert(0, err, '3 planes 2 levels error')
       call test%assert([0.10_dp, 0.3_dp, 0.6_dp], minc%volume, &
            '3 planes 2 levels volume fractions')
       call test%assert([0.0605_dp, 0.046229920797811137_dp], &
            minc%connection_area, &
            '3 planes 2 levels connection areas')
       call test%assert([0._dp, 2.8192309717077664_dp, 7.7871646178561607_dp], &
            minc%connection_distance, &
            '3 planes 2 levels connection distances')
    end if
    call minc%destroy()
    call fson_destroy_mpi(json)

  end subroutine test_geometry

!------------------------------------------------------------------------

end module minc_test
